require_dependency 'query'

class Query < ActiveRecord::Base

  def project_statement
    project_clauses = nil
    active_projects_ids = Project.active.map(&:id)
    if active_projects_ids.any?
      if has_filter?("subproject_id")
        selected_projects = Project.where(id: values_for("subproject_id").map(&:to_i))
        selected_projects_clauses = []
        case operator_for("subproject_id")
        when '='
          # include all subprojects of selected projects
          selected_projects.each do |project|
            selected_projects_clauses << "(#{Project.table_name}.lft >= #{project.lft} AND #{Project.table_name}.rgt <= #{project.rgt})"
          end
          project_clauses = selected_projects_clauses.join(' OR ') if selected_projects_clauses.any?
        when '!'
          # exclude all subprojects of selected projects
          selected_projects.each do |project|
            selected_projects_clauses << "(#{Project.table_name}.lft < #{project.lft} OR #{Project.table_name}.rgt > #{project.rgt})"
          end
          project_clauses = selected_projects_clauses.join(' AND ') if selected_projects_clauses.any?
        end
      else
        if project
          if Setting.display_subprojects_issues?
            project_clauses = "#{Project.table_name}.lft >= #{project.lft} AND #{Project.table_name}.rgt <= #{project.rgt}"
          else
            project_clauses = "#{Project.table_name}.id = %d" % project.id
          end
        end
      end
    end
    "(#{project_clauses})"
  end

end
