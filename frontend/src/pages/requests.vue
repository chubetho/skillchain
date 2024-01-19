<script setup lang="ts">
import type { Job } from '@/types'

export type JobWithRequests = Job & { requests: CustomRequest[] }
interface CustomRequest {
  id: number
  buyer: string
  message: string
  accepted: boolean
}

const store = useStore()

const jobFactory = await store.getJobFactory()
const pendingJobs = shallowRef<JobWithRequests[]>([])
const acceptedJobs = shallowRef<JobWithRequests[]>([])
const isLoading = ref(false)

async function fetch() {
  isLoading.value = true
  const jobs = (await jobFactory.getAllJobsOfUser(store.address)).map(x => ({
    owner: x[0],
    id: Number(x[1]),
    title: x[2],
    description: x[3],
    price: Number(x[4]),
    inProcess: x[5],
    tags: x[6],
    requests: [] as CustomRequest[],
  }))

  const promises = jobs.map(job => jobFactory.getJobBuyRequests(job.id))
  const res = await Promise.all(promises)
  res.forEach((x, i) => {
    const js = x.map(y => ({
      id: Number(y[1]),
      buyer: y[2],
      message: y[3],
      accepted: y[4],
    }))

    jobs[i].requests.push(...js)
  })

  const _jobs = jobs.reduce((acc, cur) => {
    cur.requests.some(r => r.accepted)
      ? acc.acceptedJobs.push(cur)
      : acc.pendingJobs.push(cur)
    return acc
  }, { pendingJobs: [] as JobWithRequests[], acceptedJobs: [] as JobWithRequests[] })

  pendingJobs.value = _jobs.pendingJobs
  acceptedJobs.value = _jobs.acceptedJobs
  isLoading.value = false
}

onMounted(() => {
  fetch()
})

async function handleAcceptRequest(jobId: number, requestId: number) {
  const response = await jobFactory.acceptBuyRequest(jobId, requestId)
  const receipt = await response.wait()
  if (receipt?.status === 1)
    await fetch()
}
</script>

<template>
  <div class="py-10 space-y-10">
    <div class="space-y-5">
      <h2 class="text-2xl font-medium flex items-center gap-1">
        <p>pending</p>
        <span class="text-muted-foreground text-base">
          ({{ pendingJobs.length }})
        </span>
      </h2>

      <RequestSection
        v-if="pendingJobs.length"
        :jobs="pendingJobs" @accept="handleAcceptRequest"
      />
      <RequestSectionSkeleton v-if="isLoading" />
    </div>

    <div class="space-y-5">
      <h2 class="text-2xl font-medium flex items-center gap-1">
        <p>accepted</p>
        <span class="text-muted-foreground text-base">
          ({{ acceptedJobs.length }})
        </span>
      </h2>

      <RequestSection
        v-if="acceptedJobs.length"
        :jobs="acceptedJobs" @accept="handleAcceptRequest"
      />
      <RequestSectionSkeleton v-if="isLoading" />
    </div>
  </div>
</template>
