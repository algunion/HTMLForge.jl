"""
    attributevalidation(attr::AbstractString)

Validate if `attr` is a valid HTML attribute name according to HTML specifications.

Attribute names must consist of one or more characters other than space characters,
NULL, quotes, apostrophes, greater-than signs, forward slashes, equals signs,
control characters, and any characters not defined by Unicode.
"""
function attributevalidation(attr::AbstractString)
    # Empty attribute names are invalid
    isempty(attr) && throw(ArgumentError("HTML attribute name cannot be empty"))

    # Check each character in the attribute name
    for c in attr
        # Explicitly check for forbidden characters for efficiency
        (isspace(c) ||                    # Space characters
         c == '\0' ||                     # NULL
         c == '"' ||                      # QUOTATION MARK
         c == '\'' ||                     # APOSTROPHE
         c == '>' ||                      # GREATER-THAN SIGN
         c == '/' ||                      # SOLIDUS
         c == '=' ||                      # EQUALS SIGN
         iscntrl(c) ||                    # Control characters
         !Unicode.isassigned(c)) &&               # Characters not defined by Unicode
            throw(InvalidAttributeException("Invalid character '$(escape_string(string(c)))' in HTML attribute name: $attr"))
    end

    return true
end

"""
    classvaluevalidation(class::AbstractString)

CSS class values validation.
"""
function classvaluevalidation(classvalue::AbstractString)
    stripped_cls = strip(classvalue)
    isempty(stripped_cls) &&
        throw(ArgumentError("Class name cannot be empty or whitespace."))
    for c in stripped_cls
        if isspace(c)
            throw(InvalidAttributeException("Class names cannot contain whitespace: '$classvalue'"))
        end
    end
    return true
end

"""
    validate(::Val{:attr}, value::AbstractString)

Validate HTML attribute names.
"""
function validate(::Val{:attr}, value::AbstractString)
    return attributevalidation(value)
end

"""
    validate(::Val{:class}, value::AbstractString)

Validate CSS class names.
"""
function validate(::Val{:class}, value::AbstractString)
    return classvaluevalidation(value)
end

"""
    validate(::Val{:attr}, value::AbstractString)

Validate HTML attribute names.
"""
function validate(::Val{:attr}, values::Vector{<:AbstractString})
    for v in values
        attributevalidation(v)
    end
    return true
end

"""
    validate(::Val{:class}, values::Vector{<:AbstractString})

Validate CSS class names.
"""
function validate(::Val{:class}, values::Vector{<:AbstractString})
    for v in values
        classvaluevalidation(v)
    end
    return true
end

"""
    @validate type value

Validate HTML elements based on their type using compile-time dispatch.

# Arguments
- `type`: Symbol indicating what to validate (`:attr` for attribute names, `:class` for class names)
- `value`: The string(s) value to validate

# Examples
```julia
@validate :attr "class"  # Validates an attribute name
@validate :attr ["id", "data-value"]  # Validates multiple attribute names
@validate :class "my-class"  # Validates a class name
@validate :class ["class1", "class2"]  # Validates multiple class names
```

# Returns
Returns `true` if validation passes, otherwise throws an error.
"""
macro validate(type, value)
    return :(validate(Val($(esc(type))), $(esc(value))))
end
