Deface::Override.new :virtual_path  => 'issue_statuses/_form',
                     :name          => 'add_resolved_field_in_issue_status_form',
                     :insert_after  => 'p:contains("is_closed")',
                     :text          => <<EOF
<p><%= f.check_box :is_resolved %></p>
EOF
