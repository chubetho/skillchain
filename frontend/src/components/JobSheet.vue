<script setup lang="ts">
import { fetchUser } from '@/lib/fetch'
import type { Job, User } from '@/types'
import { compareAddress } from '@/utils'
import { Gavel } from 'lucide-vue-next'

const props = defineProps<{
  job: Job
}>()

const emits = defineEmits<{
  (e: 'deleted'): void
}>()

const open = defineModel<boolean>('open', { default: false })

const store = useStore()
const jobFactory = await store.getJobFactory()
const seller = shallowRef<User>()
watch(() => props.job.id, async () => {
  if (seller.value?.owner === props.job.owner)
    return

  seller.value = await fetchUser(props.job.owner)
}, { immediate: true })

const message = ref('')
const error = ref('')
async function handleSendRequest() {
  if (!message.value) {
    error.value = 'message is required'
    return
  }

  const response = await jobFactory.sendBuyRequest(props.job.id, message.value)
  const receipt = await response.wait()
  if (receipt?.status === 1) {
    message.value = ''
    open.value = false
  }
}

async function handleDeleteJob() {
  const response = await jobFactory.deleteJob(props.job.id)
  const receipt = await response.wait()
  if (receipt?.status === 1) {
    open.value = false
    emits('deleted')
  }
}
</script>

<template>
  <Sheet v-model:open="open">
    <SheetContent class="sm:max-w-lg">
      <SheetHeader>
        <SheetTitle>
          {{ job.title }} #{{ job.id }}
        </SheetTitle>
        <SheetDescription>
          {{ job.description }}
        </SheetDescription>
      </SheetHeader>

      <div class="pt-5 pb-2 flex gap-2 flex-wrap">
        <Badge v-for="(t, ti) in job.tags" :key="ti" variant="secondary">
          {{ t }}
        </Badge>
      </div>

      <JobPrice>
        {{ job.price }}
      </JobPrice>

      <template v-if="!compareAddress(job.owner, store.address)">
        <form class="mt-3 space-y-3" @submit.prevent="handleSendRequest">
          <div class="space-y-1">
            <Textarea v-model="message" placeholder="leave a message" />
            <p v-if="error" class="text-destructive">
              {{ error }}
            </p>
          </div>

          <Button
            class="w-full" type="submit"
          >
            send
          </Button>
        </form>
      </template>

      <template v-else>
        <Button class="w-full mt-3" variant="destructive" @click="handleDeleteJob">
          delete
        </Button>
      </template>

      <div v-if="seller">
        <div class="space-y-2 mt-10">
          <h3 class="text-xl">
            info
          </h3>

          <div class="grid grid-cols-3 gap-2">
            <p class="text-muted-foreground">
              username
            </p>
            <div class="col-span-2">
              <Badge variant="outline">
                {{ seller.userName }}
              </Badge>
            </div>

            <p class="text-muted-foreground">
              address
            </p>
            <div class="col-span-2">
              <Badge variant="outline">
                {{ seller.owner }}
              </Badge>
            </div>

            <template v-if="seller.isJudge">
              <p class="text-muted-foreground">
                badge
              </p>
              <div class="col-span-2">
                <Badge variant="outline">
                  <Gavel :size="16" />
                </Badge>
              </div>
            </template>
          </div>
        </div>
      </div>
    </SheetContent>
  </Sheet>
</template>
