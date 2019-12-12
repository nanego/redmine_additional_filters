Deface::Override.new :virtual_path  => 'issue_statuses/_form',
                     :name          => 'add_resolved_field_in_issue_status_form',
                     :original      => '8f374ec2439b27545906aae44228462dfe14d196',
                     :insert_after  => 'p:contains("is_closed")',
                     :text          => <<EOF
<p><%= f.check_box :is_resolved %></p>
EOF
