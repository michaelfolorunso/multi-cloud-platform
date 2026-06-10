import React, { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { getProject, createTask, completeTask, deleteTask } from '../api'
import { Project, Task } from '../types'

export default function ProjectDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const [project, setProject] = useState<Project | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [newTaskTitle, setNewTaskTitle] = useState('')
  const [addingTask, setAddingTask] = useState(false)

  useEffect(() => {
    if (id) loadProject()
  }, [id])

  const loadProject = async () => {
    try {
      const data = await getProject(Number(id))
      setProject(data)
    } catch (err) {
      setError('Failed to load project')
    } finally {
      setLoading(false)
    }
  }

  const handleAddTask = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newTaskTitle.trim() || !project) return

    setAddingTask(true)
    try {
      const task = await createTask({
        title: newTaskTitle.trim(),
        project_id: project.id
      })
      setProject({
        ...project,
        tasks: [...(project.tasks || []), task]
      })
      setNewTaskTitle('')
    } catch (err) {
      setError('Failed to add task')
    } finally {
      setAddingTask(false)
    }
  }

  const handleComplete = async (taskId: number) => {
    if (!project) return
    try {
      const updated = await completeTask(taskId)
      setProject({
        ...project,
        tasks: project.tasks?.map(t => t.id === taskId ? updated : t)
      })
    } catch (err) {
      setError('Failed to complete task')
    }
  }

  const handleDeleteTask = async (taskId: number) => {
    if (!project) return
    try {
      await deleteTask(taskId)
      setProject({
        ...project,
        tasks: project.tasks?.filter(t => t.id !== taskId)
      })
    } catch (err) {
      setError('Failed to delete task')
    }
  }

  if (loading) return <div className="loading">Loading project...</div>
  if (!project) return <div className="error">Project not found</div>

  const completedCount = project.tasks?.filter(t => t.completed).length || 0
  const totalCount = project.tasks?.length || 0

  return (
    <div>
      <button
        className="btn btn-secondary"
        style={{ marginBottom: '24px' }}
        onClick={() => navigate('/')}
      >
        ← Back to Projects
      </button>

      <h2 className="page-title">{project.name}</h2>
      {project.description && (
        <p className="page-subtitle">{project.description}</p>
      )}
      <p className="page-subtitle">
        {completedCount}/{totalCount} tasks completed
      </p>

      {error && <div className="error">{error}</div>}

      {/* add task form */}
      <div className="card">
        <form onSubmit={handleAddTask} style={{ display: 'flex', gap: '12px' }}>
          <input
            type="text"
            placeholder="Add a new task..."
            value={newTaskTitle}
            onChange={e => setNewTaskTitle(e.target.value)}
            disabled={addingTask}
            style={{ flex: 1, padding: '10px 12px', border: '1px solid #d1d5db', borderRadius: '6px', fontSize: '14px' }}
          />
          <button
            type="submit"
            className="btn btn-primary"
            disabled={addingTask || !newTaskTitle.trim()}
          >
            {addingTask ? 'Adding...' : 'Add Task'}
          </button>
        </form>
      </div>

      {/* task list */}
      {totalCount === 0 ? (
        <div className="empty-state">
          <p>No tasks yet — add your first task above.</p>
        </div>
      ) : (
        project.tasks?.map(task => (
          <div
            key={task.id}
            className="card"
            style={{ opacity: task.completed ? 0.6 : 1 }}
          >
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{ flex: 1 }}>
                <p style={{
                  fontSize: '15px',
                  fontWeight: '500',
                  textDecoration: task.completed ? 'line-through' : 'none',
                  color: task.completed ? '#888' : '#333'
                }}>
                  {task.title}
                </p>
                {task.description && (
                  <p style={{ fontSize: '13px', color: '#aaa', marginTop: '4px' }}>
                    {task.description}
                  </p>
                )}
              </div>
              <div style={{ display: 'flex', gap: '8px' }}>
                {!task.completed && (
                  <button
                    className="btn btn-success"
                    style={{ fontSize: '12px', padding: '6px 12px' }}
                    onClick={() => handleComplete(task.id)}
                  >
                    Done
                  </button>
                )}
                <button
                  className="btn btn-danger"
                  style={{ fontSize: '12px', padding: '6px 12px' }}
                  onClick={() => handleDeleteTask(task.id)}
                >
                  Delete
                </button>
              </div>
            </div>
          </div>
        ))
      )}
    </div>
  )
}