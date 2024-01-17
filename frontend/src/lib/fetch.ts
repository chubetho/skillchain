import { EMPTY_ADDRESS } from '@/constants'
import type { Escrow, EscrowRequest, Job, Message, User } from '@/types'

export async function fetchEscrow(id: number): Promise<Escrow | undefined> {
  const store = useStore()
  const factory = await store.getEscrowFactory()
  const escrow = await factory.getEscrow(id)
  const buyer = escrow[2]
  const seller = escrow[3]
  if (buyer === EMPTY_ADDRESS || seller === EMPTY_ADDRESS)
    return

  return {
    escrowId: Number(escrow[0]),
    jobId: Number(escrow[1]),
    buyer: escrow[2],
    seller: escrow[3],
    money: Number(escrow[4]),
    price: Number(escrow[5]),
    started: escrow[6],
    isDone: escrow[7],
  }
}

export async function fetchUser(addr: string): Promise<User> {
  const store = useStore()
  const factory = await store.getUserFactory()
  const u = await factory.getUser(addr)
  return {
    owner: u[0],
    userName: u[1],
    isJudge: u[2],
    jobIds: u[3].map(Number),
    escrowIds: u[4].map(Number),
  }
}

export async function fetchAllJobs(): Promise<Job[]> {
  const store = useStore()
  const factory = await store.getJobFactory()
  const jobs = await factory.getAllJobs()
  return jobs.filter(x => x[0] !== EMPTY_ADDRESS).map(x => ({
    owner: x[0],
    id: Number(x[1]),
    title: x[2],
    description: x[3],
    price: Number(x[4]),
    inProcess: x[5],
    tags: x[6],
  }))
}

export async function fetchRequest(id: number): Promise<EscrowRequest> {
  const store = useStore()
  const factory = await store.getEscrowFactory()
  const request = await factory.getCurrentRequest(id)

  return {
    buyer: request[0],
    seller: request[1],
    status: Number(request[2]),
    isStartRequest: request[3],
  }
}

export async function fetchMessages(id: number): Promise<Message[]> {
  const store = useStore()
  const factory = await store.getChatFactory()
  const ms = await factory.getAllChannelMessages(id)
  return ms.map(m => ({
    sender: m[0],
    receiver: m[1],
    timestamp: Number(m[2]),
    content: m[3],
  }))
}
