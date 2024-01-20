<script setup lang="ts">
import { useToast } from '@/components/ui/toast'
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
const isNoReceiver = computed(() =>
  (!escrowsAsBuyer.value.length && !escrowsAsSeller.value.length)
  || currentEscrow.value.buyer === EMPTY_ADDRESS
  || currentEscrow.value.seller === EMPTY_ADDRESS)
const messages = shallowRef<Message[]>([])
const isNoMessage = computed(() => !messages.value.length)
const role = ref<'buyer' | 'seller'>('buyer')
const s = ref('')
const offerPrice = ref(currentEscrow.value.job.price)
const router = useRouter()
const route = useRoute()
const { toast } = useToast()

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

  const queryId = route.query.id
  if (queryId) {
    const parsed = Number.parseInt(queryId.toString())

    const inBuyer = _escrowsAsBuyer.find(e => e.escrowId === parsed)
    if (inBuyer) {
      await handleChangeEscrow(inBuyer)
      return
    }
    const inSeller = _escrowsAsSeller.find(e => e.escrowId === parsed)
    if (inSeller) {
      await handleChangeEscrow(inSeller)
      return
    }
  }

  if (_escrowsAsBuyer.length)
    await handleChangeEscrow(_escrowsAsBuyer[0])
  else if (_escrowsAsSeller.length)
    await handleChangeEscrow(_escrowsAsSeller[0])
}

onMounted(fetch)

async function handleChangeEscrow(e: CustomEscrow) {
  if (currentEscrow.value.escrowId === e.escrowId)
    return

  router.push(`/chats?id=${e.escrowId}`)
  role.value = e.buyerUsername === store.user.userName ? 'buyer' : 'seller'
  currentEscrow.value = e
  offerPrice.value = e.job.price
  messages.value = await fetchMessages(e.escrowId)
}

async function handleSendOffer() {
  const openResponse = await chatFactory.openChannel(currentEscrow.value.escrowId)
  const openReceipt = await openResponse.wait()
  if (openReceipt?.status === 1)
    toast({ title: 'step 1/3', description: 'chat channel for you and they has been opened' })

  const sendRequestResponse = await escrowFactory.sendRequest(currentEscrow.value.escrowId)
  const sendRequestReceipt = await sendRequestResponse.wait()
  if (sendRequestReceipt?.status === 1)
    toast({ title: 'step 2/3', description: 'start request has been sent' })

  const sendMessageResponse = await chatFactory.sendMessage(currentEscrow.value.escrowId, 'start request')
  const sendMessageReceipt = await sendMessageResponse.wait()
  if (sendMessageReceipt?.status === 1) {
    toast({ title: 'step 3/3', description: 'now they will see you message' })
    messages.value = await fetchMessages(currentEscrow.value.escrowId)
  }
}

const newMessage = ref('')
async function handleSend() {
  if (!newMessage.value)
    return

  const res = await chatFactory.sendMessage(currentEscrow.value.escrowId, newMessage.value)
  const receipt = await res.wait()
  if (receipt?.status === 1) {
    messages.value = await fetchMessages(currentEscrow.value.escrowId)
    newMessage.value = ''
  }
}
</script>

<template>
  <div class="py-10">
    <div class="grid grid-cols-3 gap-5">
      <div class="col-span-1" :class="escrowsAsBuyer.length ? 'border-none' : 'border rounded-md'">
        <BaseSearch v-model="s" disabled placeholder="search for chats" />

        <div class="relative my-6">
          <Separator />
          <span class="absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2 px-3 bg-background">to you</span>
        </div>

        <ScrollArea class="h-[600px]">
          <ul v-if="escrowsAsBuyer.length" class="space-y-3">
            <li
              v-for="e in escrowsAsBuyer"
              :key="e.escrowId"
              class="cursor-pointer"
              @click="handleChangeEscrow(e)"
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

          <div class="relative my-6">
            <Separator />
            <span class="absolute top-1/2 -translate-y-1/2 left-1/2 -translate-x-1/2 px-3 bg-background">from you</span>
          </div>

          <ul v-if="escrowsAsSeller.length" class="space-y-3">
            <li
              v-for="e in escrowsAsSeller"
              :key="e.escrowId"
              class="cursor-pointer"
              @click="handleChangeEscrow(e)"
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
                    <span>{{ e.buyerUsername }}</span>
                    <span class="text-muted-foreground">{{ shortenAddr(e.buyer) }}</span>
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
          <template v-if="role === 'buyer'">
            <Avatar :address=" currentEscrow.seller" :size="35" />
            <div class="space-x-2">
              <span class="font-medium">{{ currentEscrow.sellerUsername }}</span>
              <span class="text-muted-foreground">{{ currentEscrow.seller }}</span>
            </div>
          </template>
          <template v-else>
            <Avatar :address=" currentEscrow.buyer" :size="35" />
            <div class="space-x-2">
              <span class="font-medium">{{ currentEscrow.buyerUsername }}</span>
              <span class="text-muted-foreground">{{ currentEscrow.buyer }}</span>
            </div>
          </template>
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
              <template v-if="role === 'buyer'">
                <ChatBox>
                  <BaseUsername>{{ currentEscrow.sellerUsername }}</BaseUsername>
                  hat accepted your job request!
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
                <ChatBox dir="right">
                  you hat already sent job request to <BaseUsername>{{ currentEscrow.buyerUsername }}</BaseUsername>.
                </ChatBox>
                <ChatBox dir="right">
                  wait for them to accept!
                </ChatBox>
              </template>
            </template>

            <template v-else>
              <ChatBox
                v-for="{ sender, timestamp, content } in messages" :key="timestamp"
                :dir="compareAddress(sender, store.address) ? 'right' : 'left'"
              >
                {{ content }}
                <template #timestamp>
                  <p class="text-sm text-muted-foreground text-end pr-3 py-1">
                    {{ useDateFormat(timestamp, 'HH:mm DD.MM.YY').value }}
                  </p>
                </template>
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
