import React, { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getProjects, deleteProject } from '../api'
import { Project } from '../types'

export default function Home() {
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()

  useEffect(() => {
    loadProjects()
  }, [])

  const loadProjects = async () => {
    try {
      const data = await getProjects()
      setProjects(data)
    } catch (err) {
      setError('Failed to load projects')
    } finally {
      setLoading(false)
    }
  }

  const handleDelete = async (id: number) => {
    if (!window.confirm('Delete this project?')) return
    try {
      await deleteProject(id)
      setProjects(projects.filter(p => p.id !== id))
    } catch (err) {
      setError('Failed to delete project')
    }
  }

  if (loading) return <div className="loading">Loading projects...</div>

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 className="page-title">Projects</h2>
          <p className="page-subtitle">{projects.length} project{projects.length !== 1 ? 's' : ''}</p>
        </div>
        <button className="btn btn-primary" onClick={() => navigate('/projects/new')}>
          New Project
        </button>
      </div>

      {error && <div className="error">{error}</div>}

      {projects.length === 0 ? (
        <div className="empty-state">
          <p>No projects yet.</p>
          <p>Create your first project to get started.</p>
        </div>
      ) : (
        projects.map(project => (
          <div key={project.id} className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
              <div
                style={{ cursor: 'pointer', flex: 1 }}
                onClick={() => navigate(`/projects/${project.id}`)}
              >
                <h3 style={{ fontSize: '18px', fontWeight: '600', marginBottom: '6px' }}>
                  {project.name}
                </h3>
                {project.description && (
                  <p style={{ color: '#888', fontSize: '14px' }}>{project.description}</p>
                )}
                <p style={{ color: '#aaa', fontSize: '12px', marginTop: '8px' }}>
                  Created {new Date(project.created_at).toLocaleDateString()}
                </p>
              </div>
              <button
                className="btn btn-danger"
                style={{ marginLeft: '16px', fontSize: '12px', padding: '6px 12px' }}
                onClick={() => handleDelete(project.id)}
              >
                Delete
              </button>
            </div>
          </div>
        ))
      )}
    </div>
  )
}