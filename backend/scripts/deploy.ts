import type { HardhatEthersSigner } from '@nomicfoundation/hardhat-ethers/signers'
import { ethers } from 'hardhat'
import { exit } from 'node:process'
import { jobs } from '../includes/mocks'

type Contract = Awaited<ReturnType<typeof ethers.deployContract>>

async function main() {
  const signers = await ethers.getSigners()
  const admin = signers[signers.length - 1]

  const market = await ethers.deployContract('FreelancerMarketplace', [], { signer: admin })
  await market.waitForDeployment()

  const job = await ethers.deployContract('JobManager', [market.target], { signer: admin })
  const user = await ethers.deployContract('UserManager', [market.target], { signer: admin })
  const escrow = await ethers.deployContract('EscrowManager', [market.target], { signer: admin })

  if (
    market.target !== '0x73511669fd4dE447feD18BB79bAFeAC93aB7F31f'
    || job.target !== '0xB581C9264f59BF0289fA76D61B2D0746dCE3C30D'
    || user.target !== '0xC469e7aE4aD962c30c7111dc580B4adbc7E914DD'
    || escrow.target !== '0x43ca3D2C94be00692D207C6A1e60D8B325c6f12f'
  )
    throw new Error ('Wrong deployed addresses! Restart node and try again')

  await Promise.all([
    job.waitForDeployment(),
    user.waitForDeployment(),
    escrow.waitForDeployment(),
  ])

  await Promise.all([
    job.setUserManager(user.target),
    job.setEscrowManager(escrow.target),
    escrow.setUserManager(user.target),
    escrow.setJobManager(job.target),
  ])

  const isDev = true
  if (isDev) {
    const useAccount = async (s: HardhatEthersSigner, username: string) => {
      const _user = user.connect(s) as Contract
      const _job = job.connect(s) as Contract
      const _escrow = escrow.connect(s) as Contract

      await _user.registerUser(username)

      return { user: _user, job: _job, escrow: _escrow }
    }

    await user.registerUser('admin')
    for (const { title, description, price, tags } of jobs.slice(0, 3))
      await job.addJob(title, description, price, tags)

    const account0 = await useAccount(signers[0], 'acc0')
    for (const { title, description, price, tags } of jobs.slice(3, 6))
      await account0.job.addJob(title, description, price, tags)

    const account1 = await useAccount(signers[1], 'acc1')
    for (const { title, description, price, tags } of jobs.slice(6, 9))
      await account1.job.addJob(title, description, price, tags)

    const account2 = await useAccount(signers[2], 'acc2')
    for (const { title, description, price, tags } of jobs.slice(9, 10))
      await account2.job.addJob(title, description, price, tags)

    await job.sendBuyRequest(3, ' ')
    await job.sendBuyRequest(6, ' ')
    await job.sendBuyRequest(9, ' ')

    await account0.job.sendBuyRequest(0, ' ')
    await account0.job.sendBuyRequest(1, ' ')
    await account0.job.sendBuyRequest(2, ' ')

    await account1.job.sendBuyRequest(4, ' ')
    await account1.job.sendBuyRequest(5, ' ')
    await account1.job.sendBuyRequest(9, ' ')
  }
}

main().catch((error) => {
  console.error(error)
  exit(1)
})
