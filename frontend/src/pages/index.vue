<script setup lang="ts">
import { fetchAllJobs } from '@/lib/fetch'
import type { Job } from '@/types'
import { compareAddress } from '@/utils'
import { Heart } from 'lucide-vue-next'

const store = useStore()

const q = ref('')
const qDebounced = refDebounced(q, 500)
const showMyOnly = ref(false)
const sortOpt = ref<typeof sortOpts[number]['value']>('lth')
const sortOpts = [
  { label: 'price: low to high', value: 'lth' },
  { label: 'price: hight to low', value: 'htl' },
] as const

const jobs = shallowRef<Job[]>([])
const data = computed(() => {
  const my = showMyOnly.value ? jobs.value.filter(j => compareAddress(j.owner, store.address)) : jobs.value
  const f = qDebounced.value
    ? my.filter(j => JSON.stringify(j).toLowerCase().includes(q.value.toLowerCase()))
    : my
  return f.toSorted((a, b) => sortOpt.value === 'lth' ? a.price - b.price : b.price - a.price)
})

onMounted(fetch)

const isSheetOpen = ref(false)
const currentJob = shallowRef<Job>()
function handleOpenSheet(j: Job) {
  currentJob.value = j
  isSheetOpen.value = true
}

function fetch() {
  fetchAllJobs().then((res) => {
    jobs.value = res
  })
}
</script>

<template>
  <div>
    <div class="py-10">
      <BaseSearch v-model="q" placeholder="search for job title or keyword" />
    </div>

    <div class="py-8 space-y-8">
      <div class="flex justify-between items-center">
        <div class="flex items-center gap-3">
          <h1 class="text-4xl">
            jobs
          </h1>
          <Toggle v-model:pressed="showMyOnly" aria-label="toggle my job only">
            <Heart :size="20" />
          </Toggle>
        </div>
        <div class="flex items-center whitespace-nowrap gap-2">
          <span class="text-muted-foreground">
            sort by:
          </span>

          <div class="min-w-[200px]">
            <Select v-model="sortOpt">
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  <SelectItem v-for="opt in sortOpts" :key="opt.value" :value="opt.value">
                    {{ opt.label }}
                  </SelectItem>
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
        </div>
      </div>

      <ScrollArea class="h-[800px]">
        <div class="grid grid-cols-3 gap-6">
          <JobCardCreate @created="fetch" />
          <template v-if="jobs.length">
            <JobCard v-for="(job, i) in data" :key="i" v-bind="job" @click="handleOpenSheet(job)" />
          </template>

          <template v-else>
            <JobCardSkeleton v-for="i in 5" :key="i" />
          </template>
        </div>
      </ScrollArea>
    </div>

    <template v-if="currentJob">
      <JobSheet v-model:open="isSheetOpen" :job="currentJob" @deleted="fetch" />
    </template>
  </div>
</template>
