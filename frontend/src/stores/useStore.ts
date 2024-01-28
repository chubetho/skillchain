import type { ChatManager, CommitteeManager, EscrowManager, FreelancerMarketplace, JobManager, ReviewManager, UserManager } from '@/typechain'
import { ChatManager__factory, CommitteeManager__factory, EscrowManager__factory, FreelancerMarketplace__factory, JobManager__factory, ReviewManager__factory, UserManager__factory } from '@/typechain/factories'
import type { User } from '@/types'
import { shortenAddr } from '@/utils'
import type { JsonRpcSigner } from 'ethers'
import { BrowserProvider } from 'ethers'
import { defineStore } from 'pinia'

export const useStore = defineStore('metamask', () => {
  const signer = shallowRef<JsonRpcSigner>()
  const provider = shallowRef(new BrowserProvider(window.ethereum))
  const address = ref('')
  const isConnected = computed(() => !!address.value)
  const shortAddress = computed(() => shortenAddr(address.value))
  const balance = ref('0')
  const user = shallowRef<User>({
    owner: '0x0000000000000000000000000000000000000000',
    userName: '',
    isJudge: false,
    jobIds: [],
    escrowIds: [],
  })
  const isRegistered = computed(() => !!user.value.userName)

  if (window.ethereum) {
    window.ethereum.on('accountsChanged', () => window.location.reload())
    window.ethereum.on('chainChanged', () => window.location.reload())
  }

  async function connect() {
    const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' }) as string[]
    address.value = accounts[0]
    const _balance = Number(await provider.value.getBalance(address.value))
    balance.value = (_balance / 1e18).toFixed(4)
  }

  async function getSigner() {
    if (signer.value)
      return signer.value

    signer.value = await provider.value.getSigner()
    return signer.value
  }

  let marketFactory: FreelancerMarketplace
  async function getMarketFactory() {
    if (marketFactory)
      return marketFactory
    const address = import.meta.env.VITE_MARKET_ADDRESS
    return FreelancerMarketplace__factory.connect(address, await getSigner())
  }

  let jobFactory: JobManager
  async function getJobFactory() {
    if (jobFactory)
      return jobFactory
    const address = import.meta.env.VITE_JOB_ADDRESS
    return JobManager__factory.connect(address, await getSigner())
  }

  let userFactory: UserManager
  async function getUserFactory() {
    if (userFactory)
      return userFactory
    const address = import.meta.env.VITE_USER_ADDRESS
    return UserManager__factory.connect(address, await getSigner())
  }

  let escrowFactory: EscrowManager
  async function getEscrowFactory() {
    if (escrowFactory)
      return escrowFactory
    const address = import.meta.env.VITE_ESCROW_ADDRESS
    return EscrowManager__factory.connect(address, await getSigner())
  }

  let chatFactory: ChatManager
  async function getChatFactory() {
    if (chatFactory)
      return chatFactory
    const address = import.meta.env.VITE_CHAT_ADDRESS
    return ChatManager__factory.connect(address, await getSigner())
  }

  let reviewFactory: ReviewManager
  async function getReviewFactory() {
    if (reviewFactory)
      return reviewFactory
    const address = import.meta.env.VITE_REVIEW_ADDRESS
    return ReviewManager__factory.connect(address, await getSigner())
  }

  let committeeFactory: CommitteeManager
  async function getCommitteeFactory() {
    if (committeeFactory)
      return committeeFactory
    const address = import.meta.env.VITE_COMMITTEE_ADDRESS
    return CommitteeManager__factory.connect(address, await getSigner())
  }

  return {
    connect,
    getSigner,

    getMarketFactory,
    getJobFactory,
    getUserFactory,
    getEscrowFactory,
    getChatFactory,
    getReviewFactory,
    getCommitteeFactory,

    isConnected,
    address,
    shortAddress,
    isRegistered,
    user,
    balance,
  }
})
