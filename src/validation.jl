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
    validate(::Val{:attr}, value::AbstractString)

Validate HTML attribute names.
"""
function validate(::Val{:attr}, value::AbstractString)
    return attributevalidation(value)
end

"""
    @validate type value

Validate HTML elements based on their type using compile-time dispatch.

# Arguments
- `type`: Symbol indicating what to validate (`:attr` for attribute names)
- `value`: The string value to validate

# Examples
```julia
@validate :attr "class"  # Validates an attribute name
```

# Returns
Returns `true` if validation passes, otherwise throws an error.
"""
macro validate(type, value)
    return :(validate(Val($(esc(type))), $(esc(value))))
end
