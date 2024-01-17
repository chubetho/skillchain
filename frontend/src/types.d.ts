import type { Eip1193Provider } from 'ethers'
import type { EscrowRequestStatus } from './constants'

export interface Job {
  owner: string
  id: number
  title: string
  description: string
  price: number
  inProcess: boolean
  tags: string[]
}

export interface Escrow {
  escrowId: number
  jobId: number
  buyer: string
  seller: string
  money: number
  price: number
  started: boolean
  isDone: boolean
}

export interface User {
  owner: string
  userName: string
  isJudge: boolean
  jobIds: number[]
  escrowIds: number[]
}

export interface EscrowRequest {
  buyer: string
  seller: string
  status: EscrowRequestStatus
  isStartRequest: boolean
}

export interface Message {
  sender: string
  receiver: string
  timestamp: number
  content: string
}

declare global {
  interface Window {
    ethereum: Eip1193Provider &
    { on(event: string, fn: () => void): void }
  }
}
