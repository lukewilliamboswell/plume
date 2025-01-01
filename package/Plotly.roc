module [
    to_html
]

import "static/template.html" as template : Str

to_html : {} -> Str
to_html = \_ ->
    template
    |> Str.replaceFirst "{{REPLACE_ME}}"
        """
        {
            "data": [
                {
                    "x": ["giraffes", "orangutans", "monkeys"],
                    "y": [20, 14, 23],
                    "type": "bar"
                }
            ]
        }
        """
