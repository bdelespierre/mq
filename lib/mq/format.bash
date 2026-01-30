#!/usr/bin/env bash
#
# format.bash - Output format filters for mq
#

# Convert MySQL batch-mode TSV to RFC 4180 CSV.
#
# MySQL --batch escapes: \t (tab), \n (newline), \\ (backslash), \N (NULL)
# RFC 4180: comma-separated, fields with comma/quote/newline are double-quoted
tsv_to_csv() {
    awk -F'\t' '
    function csv_field(raw,    val, needs_quote) {
        val = raw

        if (val == "\\N") return ""

        gsub(/\\\\/, "\x01", val)
        gsub(/\\n/, "\n", val)
        gsub(/\\t/, "\t", val)
        gsub(/\x01/, "\\", val)

        if (val ~ /[,"\r\n]/) {
            gsub(/"/, "\"\"", val)
            val = "\"" val "\""
        }

        return val
    }

    {
        for (i = 1; i <= NF; i++) {
            if (i > 1) printf ","
            printf "%s", csv_field($i)
        }
        printf "\n"
    }
    '
}

# Convert MySQL batch-mode TSV to a JSON array of objects.
#
# MySQL --batch escapes: \t (tab), \n (newline), \\ (backslash), \N (NULL)
# Output: [{"col1":"val1",...}, ...] — all values as strings, NULL as json null
tsv_to_json() {
    awk -F'\t' '
    function json_escape(raw,    val) {
        val = raw

        gsub(/\\\\/, "\x01", val)
        gsub(/\\n/, "\n", val)
        gsub(/\\t/, "\t", val)
        gsub(/\x01/, "\\", val)

        gsub(/\\/, "\\\\", val)
        gsub(/"/, "\\\"", val)
        gsub(/\n/, "\\n", val)
        gsub(/\t/, "\\t", val)
        gsub(/\r/, "\\r", val)

        return val
    }

    NR == 1 {
        ncols = NF
        for (i = 1; i <= NF; i++) cols[i] = json_escape($i)
        next
    }

    NR == 2 { printf "[" }
    NR > 2  { printf "," }

    NR >= 2 {
        printf "{"
        for (i = 1; i <= ncols; i++) {
            if (i > 1) printf ","
            printf "\"%s\":", cols[i]
            if ($i == "\\N") {
                printf "null"
            } else {
                printf "\"%s\"", json_escape($i)
            }
        }
        printf "}"
    }

    END {
        if (NR < 2) printf "[]"
        else printf "]"
        printf "\n"
    }
    '
}
