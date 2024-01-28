<script setup lang="ts">
import type { Job } from '@/types'
import { Plus } from 'lucide-vue-next'

const emits = defineEmits<{
  (e: 'created'): void
}>()

const store = useStore()
const open = ref(false)

function emptyJob() {
  return {
    title: '',
    description: '',
    tags: [],
    price: 0,
    id: 0,
    inProcess: false,
    owner: '0x0000000000000000000000000000000000000000',
  }
}
const job = ref<Job>(emptyJob())
const error = ref({ title: '', description: '' })

const tagsStr = ref('')
watch(tagsStr, () => {
  job.value.tags = tagsStr.value.trim().split(' ')
})

const jobFactory = await store.getJobFactory()

async function handleCreateJob() {
  error.value = { title: '', description: '' }

  if (job.value.title && job.value.description) {
    const res = await jobFactory.addJob(job.value.title, job.value.description, job.value.price, job.value.tags)
    const receipt = await res.wait()
    if (receipt?.status === 1) {
      emits('created')
      job.value = emptyJob()
      tagsStr.value = ''
      open.value = false
    }
    return
  }

  if (!job.value.title)
    error.value.title = 'title is required'
  if (!job.value.description)
    error.value.description = 'description is required'
}
</script>

<template>
  <Dialog v-model:open="open">
    <DialogTrigger as-child>
      <Card class="group flex flex-center cursor-pointer hover:border-primary transition-colors">
        <Plus :size="80" class="stroke-1 text-muted-foreground group-hover:text-primary transition-colors" />
      </Card>
    </DialogTrigger>

    <DialogContent class="max-w-5xl">
      <DialogHeader>
        <DialogTitle class="text-2xl font-light">
          create new job
        </DialogTitle>
        <DialogDescription />
      </DialogHeader>

      <form class="grid grid-cols-2 gap-10 py-3 items-center" @submit.prevent="handleCreateJob">
        <div class="space-y-3">
          <div>
            <Label for="title" class="mb-1 font-light  text-muted-foreground">title</Label>
            <Input id="title" v-model="job.title" type="text" />
            <p v-if="error.title" class="text-destructive mt-1">
              {{ error.title }}
            </p>
          </div>

          <div>
            <Label for="description" class="mb-1 font-light  text-muted-foreground">description</Label>
            <Textarea id="description" v-model="job.description" />
            <p v-if="error.description" class="text-destructive mt-1">
              {{ error.description }}
            </p>
          </div>

          <div class="flex gap-3">
            <div class="w-[120px]">
              <div class="space-y-1">
                <Label for="budget" class="font-light  text-muted-foreground">budget</Label>
                <Input id="budget" v-model.number="job.price" min="0" step="1" type="number" />
              </div>
            </div>

            <div class="grow space-y-1">
              <Label for="badges" class="font-light  text-muted-foreground">badges</Label>
              <Input id="badges" v-model="tagsStr" type="text" />
            </div>
          </div>

          <Button type="submit" class="w-full !mt-6">
            create
          </Button>
        </div>

        <div class="flex items-center justify-center">
          <JobCard v-bind="job" class="w-full border-primary min-h-[210px]" />
        </div>
      </form>
    </DialogContent>
  </Dialog>
</template>
