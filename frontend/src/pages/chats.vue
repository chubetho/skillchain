<script setup lang="ts">
import { EMPTY_ADDRESS } from '@/constants'
import { fetchEscrow, fetchMessages, fetchUser } from '@/lib/fetch'
import type { Escrow, Message } from '@/types'
import { compareAddress, shortenAddr } from '@/utils'
import { Forward, MessageCircleOff } from 'lucide-vue-next'

type CustomEscrow = Escrow & { buyerUsername: string, sellerUsername: string }

const store = useStore()
const escrowFactory = await store.getEscrowFactory()
const chatFactory = await store.getChatFactory()

const escrowsAsBuyer = shallowRef<CustomEscrow[]>([])
const escrowsAsSeller = shallowRef<CustomEscrow[]>([])
const isNoReceiver = computed(() => !escrowsAsBuyer.value.length && !escrowsAsSeller.value.length)
const messages = shallowRef<Message[]>([])
const isNoMessage = computed(() => !messages.value.length)
const receiver = shallowRef({ address: EMPTY_ADDRESS, username: 'n.a.' })
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
})

async function fetch() {
  const _escrowsAsBuyer: CustomEscrow[] = []
  const _escrowsAsSeller: CustomEscrow[] = []

  for (const id of store.user.escrowIds) {
    const e = await fetchEscrow(id)
    if (!e)
      return

    const buyer = await fetchUser(e.buyer)
    const seller = await fetchUser(e.seller)
    const escrow = {
      ...e,
      buyerUsername: buyer.userName,
      sellerUsername: seller.userName,
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
  receiver.value = {
    address: e.seller,
    username: e.sellerUsername,
  }

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
      <div class="col-span-1 border rounded-md">
        <ScrollArea class="h-[800px]">
          <ul v-if="escrowsAsBuyer.length" class="space-y-3">
            <li
              v-for="e in escrowsAsBuyer"
              :key="e.escrowId"
              class="cursor-pointer"
              @click="handleChangeReceiver(e)"
            >
              <div class="border rounded-md px-2 py-4 hover:border-primary transition-colors" :class="{ 'border-primary': receiver.address === e.seller }">
                <div class="flex items-center">
                  <Avatar class="w-[20%]" :size="45" :address="e.seller" />
                  <div>
                    <div class="space-x-2">
                      <span class="font-medium">{{ e.sellerUsername }}</span>
                      <span class="text-muted-foreground">{{ shortenAddr(e.seller) }}</span>
                    </div>
                    <p>You: Lorem ipsum dolor sit amet.</p>
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
        <div class="border-b flex items-center gap-3 px-3 py-4">
          <Avatar :address="receiver.address" :size="35" />
          <div class="space-x-2">
            <span class="font-medium">{{ receiver.username }}</span>
            <span class="text-muted-foreground tracking-wide">{{ receiver.address }}</span>
          </div>
        </div>

        <div v-if="isNoReceiver" class="h-full flex-center">
          <MessageCircleOff
            :size="100"
            stroke-width="0.75"
            class="text-muted-foreground"
          />
        </div>

        <ScrollArea v-else class="grow p-3 pt-5">
          <div class="flex flex-col gap-1.5 h-full">
            <template v-if="isNoMessage">
              <ChatBox>
                {{ receiver.username }} hat accepted your job request, send an offer now
              </ChatBox>
              <ChatBox parent-class="">
                <Button size="sm" @click="handleSendOffer">
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

        <div class="mt-auto px-3 pb-4">
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
