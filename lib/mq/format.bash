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
