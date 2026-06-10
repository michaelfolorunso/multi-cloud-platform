// shapes of data coming from the API
// keeping this in one place means if the API changes we only update here

export interface Project {
    id: number
    name: string
    description: string | null
    created_at: string
    tasks?: Task[]
  }
  
  export interface Task {
    id: number
    title: string
    description: string | null
    completed: boolean
    project_id: number
    created_at: string
  }
  
  export interface CreateProjectInput {
    name: string
    description?: string
  }
  
  export interface CreateTaskInput {
    title: string
    description?: string
    project_id: number
  }