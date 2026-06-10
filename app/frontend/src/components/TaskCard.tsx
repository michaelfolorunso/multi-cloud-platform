import React from 'react'
import { Task } from '../types'

interface Props {
  task: Task
  onComplete: (id: number) => void
  onDelete: (id: number) => void
}

export default function TaskCard({ task, onComplete, onDelete }: Props) {
  return (
    <div
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
          <p style={{ fontSize: '12px', color: '#aaa', marginTop: '6px' }}>
            {task.completed ? 'Completed' : 'Pending'}
          </p>
        </div>
        <div style={{ display: 'flex', gap: '8px' }}>
          {!task.completed && (
            <button
              className="btn btn-success"
              style={{ fontSize: '12px', padding: '6px 12px' }}
              onClick={() => onComplete(task.id)}
            >
              Done
            </button>
          )}
          <button
            className="btn btn-danger"
            style={{ fontSize: '12px', padding: '6px 12px' }}
            onClick={() => onDelete(task.id)}
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  )
}