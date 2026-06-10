import React, { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { createProject } from '../api'

export default function CreateProject() {
  const [name, setName] = useState('')
  const [description, setDescription] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const navigate = useNavigate()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim()) {
      setError('Project name is required')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const project = await createProject({
        name: name.trim(),
        description: description.trim() || undefined
      })
      // go straight to the new project after creating it
      navigate(`/projects/${project.id}`)
    } catch (err) {
      setError('Failed to create project')
      setLoading(false)
    }
  }

  return (
    <div>
      <button
        className="btn btn-secondary"
        style={{ marginBottom: '24px' }}
        onClick={() => navigate('/')}
      >
        ← Back
      </button>

      <h2 className="page-title">New Project</h2>
      <p className="page-subtitle">Create a new project to start tracking tasks</p>

      {error && <div className="error">{error}</div>}

      <div className="card" style={{ maxWidth: '500px' }}>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label>Project Name *</label>
            <input
              type="text"
              placeholder="e.g. Website Redesign"
              value={name}
              onChange={e => setName(e.target.value)}
              disabled={loading}
            />
          </div>

          <div className="form-group">
            <label>Description (optional)</label>
            <textarea
              placeholder="What is this project about?"
              value={description}
              onChange={e => setDescription(e.target.value)}
              disabled={loading}
              rows={3}
              style={{ resize: 'vertical' }}
            />
          </div>

          <div style={{ display: 'flex', gap: '12px' }}>
            <button
              type="submit"
              className="btn btn-primary"
              disabled={loading}
            >
              {loading ? 'Creating...' : 'Create Project'}
            </button>
            <button
              type="button"
              className="btn btn-secondary"
              onClick={() => navigate('/')}
              disabled={loading}
            >
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}