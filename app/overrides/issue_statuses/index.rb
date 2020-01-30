unless Rails.env.test?
  Deface::Override.new :virtual_path  => 'issue_statuses/index',
                       :name          => 'add_resolved_field_table_header_to_index_page',
                       :original      => '8f374ec2439b27545906aae44228462dfe14d196',
                       :insert_before => 'th:contains("field_is_closed")',
                       :text          => <<EOF
<th><%=l(:field_is_resolved)%></th>
EOF

  Deface::Override.new :virtual_path  => 'issue_statuses/index',
                       :name          => 'add_resolved_field_to_index_page',
                       :original      => '8f374ec2439b27545906aae44228462dfe14d196',
                       :insert_before => 'td:contains("status.is_closed?")',
                       :text          => <<EOF
<td><%= checked_image status.is_resolved? %></td>
EOF
end
