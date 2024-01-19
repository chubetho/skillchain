<script setup lang="ts">
import { EMPTY_ADDRESS } from '@/constants'
import { fetchEscrow, fetchJob, fetchMessages, fetchUser } from '@/lib/fetch'
import type { Escrow, Job, Message } from '@/types'
import { compareAddress, shortenAddr } from '@/utils'
import { Forward, MessageCircleOff } from 'lucide-vue-next'

type CustomEscrow = Escrow & { buyerUsername: string, sellerUsername: string, job: Job }

const store = useStore()
const escrowFactory = await store.getEscrowFactory()
const chatFactory = await store.getChatFactory()

const escrowsAsBuyer = shallowRef<CustomEscrow[]>([])
const escrowsAsSeller = shallowRef<CustomEscrow[]>([])
const isNoReceiver = computed(() => !escrowsAsBuyer.value.length && !escrowsAsSeller.value.length)
const messages = shallowRef<Message[]>([])
const isNoMessage = computed(() => !messages.value.length)
const currentEscrow = shallowRef<CustomEscrow>({
  buyer: EMPTY_ADDRESS,
  buyerUsername: 'n.a.',
  escrowId: -1,
  isDone: false,
  jobId: -1,
  money: 0,
  price: 0,
  seller: EMPTY_ADDRESS,
  sellerUsername: 'n.a.',
  started: false,
  job: { description: '', id: -1, inProcess: false, owner: EMPTY_ADDRESS, price: 0, tags: [], title: '' },
})
const q = ref('')
const offerPrice = ref(currentEscrow.value.job.price)

async function fetch() {
  const _escrowsAsBuyer: CustomEscrow[] = []
  const _escrowsAsSeller: CustomEscrow[] = []

  for (const id of store.user.escrowIds) {
    const e = await fetchEscrow(id)
    if (!e)
      return

    const buyer = await fetchUser(e.buyer)
    const seller = await fetchUser(e.seller)
    const job = await fetchJob(e.jobId)
    const escrow = {
      ...e,
      buyerUsername: buyer.userName,
      sellerUsername: seller.userName,
      job,
    }

    if (compareAddress(buyer.owner, store.address))
      _escrowsAsBuyer.push(escrow)
    else
      _escrowsAsSeller.push(escrow)
  }

  escrowsAsBuyer.value = _escrowsAsBuyer
  escrowsAsSeller.value = _escrowsAsSeller

  _escrowsAsBuyer.length && await handleChangeReceiver(_escrowsAsBuyer[0])
}

onMounted(() => {
  fetch()
})

async function handleChangeReceiver(e: CustomEscrow) {
  if (currentEscrow.value.escrowId === e.escrowId)
    return

  currentEscrow.value = e
  offerPrice.value = e.job.price
  messages.value = await fetchMessages(e.escrowId)
}

async function handleSendOffer() {
  isNoMessage.value && await chatFactory.openChannel(currentEscrow.value.escrowId)
  await escrowFactory.sendRequest(currentEscrow.value.escrowId)
  await chatFactory.sendMessage(currentEscrow.value.escrowId, 'start request')
}

const newMessage = ref('')
async function handleSend() {
  if (!newMessage.value)
    return

  const res = await chatFactory.sendMessage(currentEscrow.value.escrowId, newMessage.value)
  const receipt = await res.wait()
  if (receipt?.status === 1)
    messages.value = await fetchMessages(currentEscrow.value.escrowId)
}
</script>

<template>
  <div class="py-10">
    <div class="grid grid-cols-3 gap-5">
      <div class="col-span-1 space-y-3" :class="escrowsAsBuyer.length ? 'border-none' : 'border rounded-md'">
        <BaseSearch v-model="q" placeholder="search for chats" />
        <ScrollArea class="h-[600px]">
          <ul v-if="escrowsAsBuyer.length" class="space-y-3">
            <li
              v-for="e in escrowsAsBuyer"
              :key="e.escrowId"
              class="cursor-pointer"
              @click="handleChangeReceiver(e)"
            >
              <div class="border rounded-md px-4 py-3 hover:border-primary transition-colors" :class="{ 'border-primary': e.escrowId === currentEscrow.escrowId }">
                <div class="space-y-1">
                  <div class="flex items-center justify-between w-">
                    <p class="font-medium">
                      #{{ e.jobId }} {{ e.job.title }}
                    </p>
                    <JobPrice>
                      <template #parent>
                        <span class="font-normal mr-1">{{ e.job.price }}</span>
                      </template>
                    </JobPrice>
                  </div>

                  <div class="space-x-1">
                    <span>{{ e.sellerUsername }}</span>
                    <span class="text-muted-foreground">{{ shortenAddr(e.seller) }}</span>
                  </div>
                </div>
              </div>
            </li>
          </ul>

          <div v-if="isNoReceiver" class="pt-6 text-center">
            <p class="text-muted-foreground">
              there is no chat
            </p>
          </div>
        </ScrollArea>
      </div>

      <div class="col-span-2 flex flex-col border rounded-md">
        <div class="border-b flex items-center gap-3 p-3">
          <Avatar :address="currentEscrow.seller" :size="35" />
          <div class="space-x-2">
            <span class="font-medium">{{ currentEscrow.sellerUsername }}</span>
            <span class="text-muted-foreground">{{ currentEscrow.seller }}</span>
          </div>
        </div>

        <div v-if="isNoReceiver" class="h-full flex-center">
          <MessageCircleOff
            :size="100"
            stroke-width="0.75"
            class="text-muted-foreground"
          />
        </div>

        <ScrollArea v-else class="grow p-3">
          <div class="flex flex-col gap-2 h-full">
            <template v-if="isNoMessage">
              <ChatBox>
                {{ currentEscrow.sellerUsername }} hat accepted your job request!
              </ChatBox>
              <ChatBox>
                send an offer now to start and contact with them.
              </ChatBox>
              <ChatBox parent-class="">
                <Input v-model="offerPrice" type="number" :min="currentEscrow.job.price" class="w-[100px] inline rounded-br-none rounded-tr-none" />
                <Button size="sm" class="rounded-bl-none rounded-tl-none" @click="handleSendOffer">
                  send
                </Button>
              </ChatBox>
            </template>

            <template v-else>
              <ChatBox
                v-for="{ sender, timestamp, content } in messages" :key="timestamp"
                :dir="compareAddress(sender, store.address) ? 'right' : 'left'"
              >
                {{ content }}
              </ChatBox>
            </template>
          </div>
        </ScrollArea>

        <div class="mt-auto p-3">
          <form class="flex items-center gap-3" @submit.prevent="handleSend">
            <div class="grow">
              <Input v-model="newMessage" placeholder="type something here..." />
            </div>
            <Button size="icon" :disabled="isNoReceiver || isNoMessage">
              <Forward :size="20" />
            </Button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
