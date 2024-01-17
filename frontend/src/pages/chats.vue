<script setup lang="ts">
import { EMPTY_ADDRESS } from '@/constants'
import { fetchEscrow, fetchUser } from '@/lib/fetch'
import type { Escrow } from '@/types'
import { compareAddress, shortenAddr } from '@/utils'
import { Forward, MessageCircleOff } from 'lucide-vue-next'

type CustomEscrow = Escrow & { buyerUsername: string, sellerUsername: string }

const store = useStore()
const escrowFactory = await store.getEscrowFactory()
// const chatFactory = await store.getChatFactory()
// onMounted(async () =>
//   console.log(await chatFactory.getAllChannelMessages(0)),
// )

const escrowsAsBuyer = shallowRef<CustomEscrow[]>([])
const escrowsAsSeller = shallowRef<CustomEscrow[]>([])
const isNoChat = computed(() => !escrowsAsBuyer.value.length && !escrowsAsSeller.value.length)

const receiver = shallowRef({ address: EMPTY_ADDRESS, username: 'n.a.' })

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
}

onMounted(() => {
  fetch()
})

async function handleSendOffer() {
  await escrowFactory.sendRequest(0)
}

const message = ref('')
function handleSend() {
  console.log(message.value)
}
</script>

<template>
  <div class="py-10">
    <div class="grid grid-cols-3 gap-5">
      <div class="col-span-1 border rounded-md">
        <ScrollArea class="h-[800px]">
          <ul v-if="escrowsAsBuyer.length" class="space-y-3">
            <li
              v-for="escrow in escrowsAsBuyer"
              :key="escrow.escrowId"
              class="cursor-pointer"
              @click="receiver = { address: escrow.seller, username: escrow.sellerUsername }"
            >
              <div class="border rounded-md px-2 py-4 hover:border-primary transition-colors" :class="{ 'border-primary': receiver.address === escrow.seller }">
                <div class="flex items-center">
                  <Avatar class="w-[20%]" :size="45" :address="escrow.seller" />
                  <div>
                    <div class="space-x-2">
                      <span class="font-medium">{{ escrow.sellerUsername }}</span>
                      <span class="text-muted-foreground">{{ shortenAddr(escrow.seller) }}</span>
                    </div>
                    <p>You: Lorem ipsum dolor sit amet.</p>
                  </div>
                </div>
              </div>
            </li>
          </ul>

          <ul v-if="escrowsAsSeller.length" class="space-y-3">
            <li
              v-for="escrow in escrowsAsSeller"
              :key="escrow.escrowId"
              class="cursor-pointer"
              @click="receiver = { address: escrow.seller, username: escrow.sellerUsername }"
            >
              <div class="border rounded-md px-2 py-4 hover:border-primary transition-colors" :class="{ 'border-primary': receiver.address === escrow.seller }">
                <div class="flex items-center">
                  <Avatar class="w-[20%]" :size="45" :address="escrow.seller" />
                  <div>
                    <div class="space-x-2">
                      <span class="font-medium">{{ escrow.sellerUsername }}</span>
                      <span class="text-muted-foreground">{{ shortenAddr(escrow.seller) }}</span>
                    </div>
                    <p>You: Lorem ipsum dolor sit amet.</p>
                  </div>
                </div>
              </div>
            </li>
          </ul>

          <div v-if="isNoChat" class="pt-6 text-center">
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

        <div v-if="isNoChat" class="h-full flex-center">
          <MessageCircleOff
            :size="100"
            stroke-width="0.75"
            class="text-muted-foreground"
          />
        </div>

        <ScrollArea v-else class="grow p-3 pt-5">
          <div class="flex flex-col gap-3 h-full">
            <ChatBox>
              {{ receiver.username }} hat accepted your job request. send an offer now.
            </ChatBox>

            <ChatBox>
              <Button @click="handleSendOffer">
                send
              </Button>
            </ChatBox>
          </div>
        </ScrollArea>

        <div class="mt-auto px-3 pb-4">
          <form class="flex items-center gap-3" @submit.prevent="handleSend">
            <div class="grow">
              <Input v-model="message" placeholder="type something here..." />
            </div>
            <Button size="icon" :disabled="isNoChat">
              <Forward :size="20" />
            </Button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
