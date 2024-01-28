<script setup lang="ts">
import type { JobWithRequests } from '@/pages/requests.vue'
import { ChevronDown, CornerDownRight } from 'lucide-vue-next'

defineProps<{
  jobs: JobWithRequests[]
}>()

const emits = defineEmits<{
  (e: 'accept', jobId: number, requestId: number): void
}>()

const jobId = ref(-1)
</script>

<template>
  <ScrollArea class="h-[500px]">
    <ul class="space-y-5">
      <li v-for="j in jobs" :key="j.id">
        <div class="px-5 py-3 border rounded-md grid grid-cols-11 gap-10">
          <div class="space-y-2 col-span-5">
            <div class="font-medium">
              {{ j.title }} #{{ j.id }}
            </div>
            <div class="text-muted-foreground">
              {{ j.description }}
            </div>
          </div>

          <div class="space-y-2 col-span-5">
            <ul class="flex gap-2">
              <li v-for="(t, ti) in j.tags" :key="ti">
                <Badge variant="secondary">
                  {{ t }}
                </Badge>
              </li>
            </ul>

            <JobPrice>
              {{ j.price }}
            </JobPrice>
          </div>

          <div class="flex items-center justify-end">
            <Button :disabled="!j.requests.length" variant="outline" size="icon" @click="jobId = jobId === j.id ? -1 : j.id">
              <ChevronDown class="transition-transform" :class="{ 'rotate-180': j.id === jobId }" />
            </Button>
          </div>
        </div>

        <Transition
          enter-active-class="transition-all duration-500 ease"
          leave-active-class="transition-all duration-500 ease"
          enter-from-class="opacity-0 translate-x-[10rem]"
          leave-to-class="opacity-0 translate-x-[10rem]"
        >
          <template v-if="j.requests.length && j.id === jobId">
            <ul>
              <li v-for="r in j.requests" :key="r.id">
                <div class="w-[70%] ml-auto mt-5 flex gap-5 items-center">
                  <CornerDownRight :size="16" />

                  <div class="px-5 py-3 border rounded-md grow flex gap-5 items-center">
                    <div class="space-y-5 grow">
                      <div class="flex">
                        <span class="w-20 shrink-0">from</span>
                        <span class="font-medium"> {{ r.buyer }}</span>
                      </div>
                      <div class="flex">
                        <span class="w-20 shrink-0">message:</span>
                        <div class="px-3 py-2 bg-secondary border rounded-md grow">
                          {{ r.message }}
                        </div>
                      </div>
                    </div>

                    <RouterLink v-if="r.accepted" :to="{ path: '/chats', query: { id: r.escrowId } }">
                      <Button>
                        to chat
                      </Button>
                    </RouterLink>
                    <Button v-else @click="emits('accept', jobId, r.id)">
                      accept
                    </Button>
                  </div>
                </div>
              </li>
            </ul>
          </template>
        </Transition>
      </li>
    </ul>
  </ScrollArea>
</template>
