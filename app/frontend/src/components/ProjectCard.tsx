import React from 'react'
import { useNavigate } from 'react-router-dom'
import { Project } from '../types'

interface Props {
  project: Project
  onDelete: (id: number) => void
}

export default function ProjectCard({ project, onDelete }: Props) {
  const navigate = useNavigate()
  const taskCount = project.tasks?.length || 0
  const completedCount = project.tasks?.filter(t => t.completed).length || 0

  return (
    <div className="card">
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div
          style={{ cursor: 'pointer', flex: 1 }}
          onClick={() => navigate(`/projects/${project.id}`)}
        >
          <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '6px' }}>
            {project.name}
          </h3>
          {project.description && (
            <p style={{ color: '#888', fontSize: '14px', marginBottom: '8px' }}>
              {project.description}
            </p>
          )}
          <p style={{ color: '#aaa', fontSize: '12px' }}>
            {taskCount > 0
              ? `${completedCount}/${taskCount} tasks completed`
              : 'No tasks yet'}
             · Created {new Date(project.created_at).toLocaleDateString()}
          </p>
        </div>
        <button
          className="btn btn-danger"
          style={{ marginLeft: '16px', fontSize: '12px', padding: '6px 12px' }}
          onClick={() => onDelete(project.id)}
        >
          Delete
        </button>
      </div>
    </div>
  )
}