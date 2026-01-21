from django import template

register = template.Library()

@register.filter(name='remove_underscore')
def remove_underscore(value):
    """Remove underscores and replace with spaces"""
    if isinstance(value, str):
        return value.replace('_', ' ')
    return value

@register.filter(name='format_field_name')
def format_field_name(value):
    """Format field name: remove underscores and title case"""
    if isinstance(value, str):
        # Replace underscores with spaces and title case
        return value.replace('_', ' ').title()
    return value
