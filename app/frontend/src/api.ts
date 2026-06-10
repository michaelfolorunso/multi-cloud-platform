import axios from 'axios'
import { Project, Task, CreateProjectInput, CreateTaskInput } from './types'

// base URL from environment variable
// locally points to docker-compose backend, in k8s points to the service
const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: API_BASE,
  headers: {
    'Content-Type': 'application/json'
  }
})

// projects
export const getProjects = async (): Promise<Project[]> => {
  const response = await api.get('/projects')
  return response.data
}

export const getProject = async (id: number): Promise<Project> => {
  const response = await api.get(`/projects/${id}`)
  return response.data
}

export const createProject = async (data: CreateProjectInput): Promise<Project> => {
  const response = await api.post('/projects', data)
  return response.data
}

export const deleteProject = async (id: number): Promise<void> => {
  await api.delete(`/projects/${id}`)
}

// tasks
export const getTasks = async (projectId?: number): Promise<Task[]> => {
  const params = projectId ? { project_id: projectId } : {}
  const response = await api.get('/tasks', { params })
  return response.data
}

export const createTask = async (data: CreateTaskInput): Promise<Task> => {
  const response = await api.post('/tasks', data)
  return response.data
}

export const completeTask = async (id: number): Promise<Task> => {
  const response = await api.patch(`/tasks/${id}/complete`)
  return response.data
}

export const deleteTask = async (id: number): Promise<void> => {
  await api.delete(`/tasks/${id}`)
}