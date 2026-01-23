from django import template

register = template.Library()


@register.filter(name='get_field')
def get_field(obj, field_name):
    """
    Template filter to get a field value from an object dynamically
    Usage: {{ obj|get_field:"field_name" }}
    """
    try:
        return getattr(obj, field_name, None)
    except (AttributeError, TypeError):
        return None


@register.filter(name='replace')
def replace(value, arg):
    """
    Template filter to replace characters in a string
    Usage: {{ value|replace:"_":" " }}
    """
    if not isinstance(value, str):
        value = str(value)

    if ":" in arg:
        old, new = arg.split(":", 1)
        return value.replace(old, new)
    return value
