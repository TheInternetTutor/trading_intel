
#-----------------------------------------------------------------------
function initialize()
{
    FS=","
    OFS = "\n"

    lines_processed = 0
    lines_modified  = 0
    total_replacements = 0

    idx_old      = 0
    idx_new      = 0
    idx_enabled  = 0
    idx_comment  = 0

}

#-----------------------------------------------------------------------
function load_csv(file,
                  line,
                  n,
                  fields,
                  old_name,
                  new_name,
                  enabled,
                  header)
{
    header = 1

    while ((getline line < file) > 0)
    {
        line = trim(line)

        #
        # Skip blank lines
        #

        if (line == "")
            continue

        #
        # Skip comments
        #

        if (substr(line,1,1) == "#")
            continue

        if (substr(line,1,1) == ";")
            continue

        n = split(line, fields, ",")

        #
        # Process header
        #

        if (header)
        {
            detect_columns(fields, n)
            header = 0
            continue
        }

        old_name = trim(fields[idx_old])
        new_name = trim(fields[idx_new])

        #
        # Ignore incomplete mappings
        #

        if (old_name == "" || new_name == "")
            continue

        #
        # Honor optional enabled column
        #

        if (idx_enabled)
        {
            enabled = trim(fields[idx_enabled])

            if (tolower(enabled) != "yes")
                continue
        }

        rename[old_name] = new_name
    }

    close(file)
}

#-----------------------------------------------------------------------
function detect_columns(fields, n,
                        i)
{

    for (i = 1; i <= n; i++)
    {
        gsub(/^ +| +$/, "", fields[i])

        if (fields[i] == "old_name")
            idx_old = i

        else if (fields[i] == "new_name")
            idx_new = i

        else if (fields[i] == "enabled")
            idx_enabled = i

        else if (fields[i] == "comment")
            idx_comment = i
    }

    if (!idx_old)
        fatal("CSV missing old_name column")

    if (!idx_new)
        fatal("CSV missing new_name column")
}

#-----------------------------------------------------------------------
function fatal(message)
{
    print message > "/dev/stderr"
    exit 1
}

#-----------------------------------------------------------------------
function trim(str)
{
    gsub(/^[[:space:]]+/, "", str)
    gsub(/[[:space:]]+$/, "", str)
    return str
}

#-----------------------------------------------------------------------
function is_identifier_char(ch)
{
    return (ch ~ /[A-Za-z0-9_]/)
}

#-----------------------------------------------------------------------
function replace_identifier(line,
                            result,
                            i,
                            ch,
                            token,
                            next_char)
{
    result = ""

    i = 1

    while (i <= length(line))
    {
        ch = substr(line, i, 1)

        if (!is_identifier_char(ch))
        {
            result = result ch
            i++
            continue
        }

        token = ""

        while (i <= length(line))
        {
            next_char = substr(line, i, 1)

            if (!is_identifier_char(next_char))
                break

            token = token next_char
            i++
        }

        if (token in rename)
        {
            result = result rename[token]
            total_replacements++
        }
        else
        {
            result = result token
        }
    }

    return result
}

#-----------------------------------------------------------------------
function process_line(original)
{
    original = $0

    $0 = replace_identifier($0)

    if ($0 != original)
        lines_modified++
}

#-----------------------------------------------------------------------
function print_statistics()
{
    if (verbose)
    {
        print ""
        print "Lines processed    : " lines_processed
        print "Lines modified     : " lines_modified
        print "Identifiers changed: " total_replacements
    }
}

#=======================================================================
BEGIN {
    initialize()
    load_csv(csv)
}

#=======================================================================
{
    lines_processed++
    process_line()
    print
}

#=======================================================================
END {
    print_statistics()
}
