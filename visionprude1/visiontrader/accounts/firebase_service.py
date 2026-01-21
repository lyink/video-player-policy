"""
Firebase Service Module
Handles all Firebase Firestore interactions with caching and rate limiting
"""
import os
import time
import firebase_admin
from firebase_admin import credentials, firestore
from django.conf import settings
from django.core.cache import cache
from google.api_core.exceptions import ResourceExhausted, DeadlineExceeded
from functools import wraps


class FirebaseService:
    """Service class for Firebase operations with caching and rate limiting"""

    _initialized = False
    _db = None

    # Cache timeouts (in seconds)
    CACHE_TIMEOUT_COLLECTIONS = 300  # 5 minutes for collection list
    CACHE_TIMEOUT_DATA = 60  # 1 minute for collection data

    # Rate limiting
    _last_request_time = 0
    _min_request_interval = 0.5  # Minimum 0.5 seconds between requests

    @classmethod
    def initialize(cls):
        """Initialize Firebase Admin SDK"""
        if cls._initialized:
            return cls._db

        try:
            # Path to your Firebase service account key
            cred_path = os.path.join(settings.BASE_DIR, 'firebase-credentials.json')

            if not os.path.exists(cred_path):
                print(f"Warning: Firebase credentials not found at {cred_path}")
                return None

            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            cls._db = firestore.client()
            cls._initialized = True
            print("Firebase initialized successfully")
            return cls._db

        except Exception as e:
            print(f"Error initializing Firebase: {e}")
            return None

    @classmethod
    def get_db(cls):
        """Get Firestore database instance"""
        if not cls._initialized:
            return cls.initialize()
        return cls._db

    @classmethod
    def _rate_limit(cls):
        """Enforce rate limiting between requests"""
        current_time = time.time()
        time_since_last_request = current_time - cls._last_request_time

        if time_since_last_request < cls._min_request_interval:
            sleep_time = cls._min_request_interval - time_since_last_request
            time.sleep(sleep_time)

        cls._last_request_time = time.time()

    @classmethod
    def _retry_with_backoff(cls, func, max_retries=3, initial_delay=1):
        """
        Retry a function with exponential backoff on quota errors

        Args:
            func: Function to retry
            max_retries: Maximum number of retry attempts
            initial_delay: Initial delay in seconds

        Returns:
            Result of the function or None on failure
        """
        delay = initial_delay

        for attempt in range(max_retries):
            try:
                cls._rate_limit()  # Apply rate limiting before each attempt
                return func()
            except (ResourceExhausted, DeadlineExceeded) as e:
                if attempt < max_retries - 1:
                    print(f"Quota error, retrying in {delay} seconds... (attempt {attempt + 1}/{max_retries})")
                    time.sleep(delay)
                    delay *= 2  # Exponential backoff
                else:
                    print(f"Max retries reached. Error: {e}")
                    return None
            except Exception as e:
                print(f"Unexpected error: {e}")
                return None

        return None

    @classmethod
    def get_collection(cls, collection_name, use_cache=True, limit=None):
        """
        Get all documents from a collection with caching

        Args:
            collection_name (str): Name of the Firestore collection
            use_cache (bool): Whether to use cached data
            limit (int): Optional limit on number of documents to fetch

        Returns:
            list: List of document dictionaries with 'id' and data
        """
        # Check cache first
        cache_key = f'firebase_collection_{collection_name}'
        if use_cache:
            cached_data = cache.get(cache_key)
            if cached_data is not None:
                print(f"Returning cached data for collection: {collection_name}")
                return cached_data

        db = cls.get_db()
        if not db:
            return []

        def fetch_collection():
            """Internal function to fetch collection data"""
            query = db.collection(collection_name)

            if limit:
                query = query.limit(limit)

            docs = query.stream(timeout=30.0)  # Set a 30-second timeout
            results = []

            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                results.append(data)

            return results

        try:
            # Fetch with retry logic
            results = cls._retry_with_backoff(fetch_collection)

            if results is not None:
                # Cache the results
                cache.set(cache_key, results, cls.CACHE_TIMEOUT_DATA)
                print(f"Successfully fetched and cached {len(results)} documents from {collection_name}")
                return results
            else:
                print(f"Failed to fetch collection {collection_name} after retries")
                return []

        except Exception as e:
            print(f"Error fetching collection {collection_name}: {e}")
            return []

    @classmethod
    def get_document(cls, collection_name, document_id):
        """
        Get a specific document from a collection

        Args:
            collection_name (str): Name of the Firestore collection
            document_id (str): Document ID

        Returns:
            dict: Document data or None if not found
        """
        db = cls.get_db()
        if not db:
            return None

        try:
            doc_ref = db.collection(collection_name).document(document_id)
            doc = doc_ref.get()

            if doc.exists:
                data = doc.to_dict()
                data['id'] = doc.id
                return data
            return None

        except Exception as e:
            print(f"Error fetching document {document_id}: {e}")
            return None

    @classmethod
    def query_collection(cls, collection_name, field, operator, value):
        """
        Query a collection with a filter

        Args:
            collection_name (str): Name of the Firestore collection
            field (str): Field to filter on
            operator (str): Comparison operator (==, <, >, <=, >=, !=)
            value: Value to compare against

        Returns:
            list: List of matching documents
        """
        db = cls.get_db()
        if not db:
            return []

        try:
            query = db.collection(collection_name).where(field, operator, value)
            docs = query.stream()

            results = []
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                results.append(data)

            return results

        except Exception as e:
            print(f"Error querying collection: {e}")
            return []

    @classmethod
    def get_all_collections(cls, use_cache=True):
        """
        Get list of all collection names with caching

        Args:
            use_cache (bool): Whether to use cached data

        Returns:
            list: List of collection names
        """
        # Check cache first
        cache_key = 'firebase_all_collections'
        if use_cache:
            cached_collections = cache.get(cache_key)
            if cached_collections is not None:
                print(f"Returning cached collection list ({len(cached_collections)} collections)")
                return cached_collections

        db = cls.get_db()
        if not db:
            return []

        def fetch_collections():
            """Internal function to fetch collections"""
            collections = db.collections(timeout=30.0)  # Set a 30-second timeout
            return [collection.id for collection in collections]

        try:
            # Fetch with retry logic
            results = cls._retry_with_backoff(fetch_collections)

            if results is not None:
                # Cache the results
                cache.set(cache_key, results, cls.CACHE_TIMEOUT_COLLECTIONS)
                print(f"Successfully fetched and cached {len(results)} collections")
                return results
            else:
                print("Failed to fetch collections after retries")
                return []

        except Exception as e:
            print(f"Error fetching collections: {e}")
            return []

    @classmethod
    def clear_cache(cls, collection_name=None):
        """
        Clear cached data

        Args:
            collection_name (str): Specific collection to clear, or None to clear all
        """
        if collection_name:
            cache_key = f'firebase_collection_{collection_name}'
            cache.delete(cache_key)
            print(f"Cleared cache for collection: {collection_name}")
        else:
            # Clear all Firebase-related caches
            cache.delete('firebase_all_collections')
            print("Cleared all Firebase caches")
