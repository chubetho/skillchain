<script setup lang="ts">
import { EMPTY_ADDRESS } from '@/constants'
import { fetchUser } from '@/lib/fetch'
import type { Review, ReviewResponse } from '@/types'
import { Reply, Star } from 'lucide-vue-next'

const props = defineProps<{
  escrowId: number
}>()

const store = useStore()
const reviewFactory = await store.getReviewFactory()

const review = ref<Review>()
const rating = ref(0)
const comment = ref('')
const isRatingError = ref(false)
const isCommentError = ref(false)
watch(comment, (v) => {
  if (v.length >= 5)
    isCommentError.value = false
})

async function handleReview() {
  isRatingError.value = false
  isCommentError.value = false

  if (rating.value < 1 || rating.value > 5) {
    isRatingError.value = true
    return
  }

  if (comment.value.length < 5) {
    isCommentError.value = true
    return
  }

  const request = await reviewFactory.createReview(props.escrowId, rating.value, comment.value)
  const receipt = await request.wait()
  if (receipt?.status === 1)
    await findReviewAndResponse()
}

const reviewResponse = ref<ReviewResponse>()
const response = ref('')
const isResponseError = ref(false)
const isResponseOpen = ref(false)
watch(response, (v) => {
  if (v.length >= 5)
    isResponseError.value = false
})

async function handleResponseToReview() {
  if (!review.value)
    return

  isResponseError.value = false

  if (response.value.length < 5) {
    isResponseError.value = true
    return
  }

  const request = await reviewFactory.createResponse(review.value.id, response.value)
  const receipt = await request.wait()
  if (receipt?.status === 1)
    console.log(await reviewFactory.getResponse(review.value.id))
}

function handleChooseRating(v: number) {
  rating.value = v
  isRatingError.value = false
}

const reviewingUsername = ref(EMPTY_ADDRESS)
const beingReviewedUsername = ref(EMPTY_ADDRESS)

async function findReviewAndResponse() {
  try {
    const _review = await reviewFactory.getReviewByEscrowId(props.escrowId)
    if (_review[2] === EMPTY_ADDRESS || _review[3] === EMPTY_ADDRESS)
      return

    review.value = {
      timestamp: Number(_review[0]),
      rating: Number(_review[1]),
      reviewingAddress: _review[2],
      beingReviewedAddress: _review[3],
      reviewComment: _review[4],
      relevantEscrowId: Number(_review[5]),
      responded: _review[6],
      id: Number(_review[7]),
    }

    reviewingUsername.value = (await fetchUser(review.value.reviewingAddress)).userName
    beingReviewedUsername.value = (await fetchUser(review.value.beingReviewedAddress)).userName

    const _response = await reviewFactory.getResponse(review.value.id)
    if (_response[1] === EMPTY_ADDRESS)
      return
    reviewResponse.value = {
      timestamp: Number(_response[0]),
      responder: _response[1],
      responseComment: _response[2],
    }
  }
  catch (e) {
    console.log(e)
  }
}

onMounted(findReviewAndResponse)
</script>

<template>
  <div class="py-3">
    <p class="text-sm text-center text-muted-foreground">
      this channel is closed
    </p>

    <div v-if="review">
      <div class="border px-4 py-3 rounded-md mt-6 space-y-3 w-4/5 mx-auto">
        <div class="flex items-center gap-3 min-h-10">
          <ul class="flex items-center gap-1">
            <li v-for="i in 5" :key="i">
              <Star
                :class="{ 'fill-primary': i <= review.rating }"
                stroke-width="1.25"
              />
            </li>
          </ul>
          <p class="text-muted-foreground">
            {{ useDateFormat(review.timestamp, 'HH:mm DD.MM.YYYY').value }}
          </p>

          <Button
            v-if="reviewingUsername === store.user.userName && !reviewResponse"
            size="icon"
            class="ml-auto"
            variant="ghost"
            @click="isResponseOpen = !isResponseOpen"
          >
            <Reply />
          </Button>
        </div>

        <p> <BaseUsername>{{ reviewingUsername }}: </BaseUsername>  {{ review.reviewComment }}</p>

        <div v-if="reviewResponse" class="bg-secondary p-3 rounded-md space-y-1">
          <p class="text-muted-foreground">
            {{ useDateFormat(reviewResponse.timestamp, 'HH:mm DD.MM.YYYY').value }}
          </p>
          <p> <BaseUsername>{{ beingReviewedUsername }}: </BaseUsername> {{ reviewResponse.responseComment }}</p>
        </div>
      </div>

      <Transition
        enter-active-class="transition-all"
        leave-active-class="transition-all"
        enter-from-class="translate-y-[-30px] opacity-0"
        leave-to-class="translate-y-[-30px] opacity-0"
      >
        <div v-if="isResponseOpen" class="border px-4 py-3 rounded-md w-4/5 mx-auto mt-3">
          <form class="space-y-3" @submit.prevent="handleResponseToReview">
            <Textarea
              v-model="response"
              :class="{ 'border-destructive focus-visible:ring-destructive': isResponseError }"
              placeholder="your respond..."
            />
            <p v-if="isResponseError" class="text-destructive">
              response must have at least 5 characters
            </p>

            <Button class="w-full mt-3">
              response
            </Button>
          </form>
        </div>
      </Transition>
    </div>

    <form v-else class="flex flex-col items-center justify-center gap-3 mt-6" @submit.prevent="handleReview">
      <div class="flex items-center gap-3">
        <ul class="flex items-center gap-1">
          <li
            v-for="i in 5" :key="i"
            class="cursor-pointer"
            @click="handleChooseRating(i)"
          >
            <Star :class="{ 'fill-primary': i <= rating, 'text-destructive': isRatingError }" stroke-width="1.25" />
          </li>
        </ul>

        <span class="mt-1">{{ rating }} / 5</span>
      </div>

      <div class="w-1/2 space-y-3">
        <Textarea
          v-model="comment"
          :class="{ 'border-destructive focus-visible:ring-destructive': isCommentError }"
          placeholder="your review..."
        />

        <p v-if="isRatingError" class="text-destructive">
          rating must be from 1 to 5 stars
        </p>

        <p v-if="isCommentError" class="text-destructive">
          comment must have at least 5 characters
        </p>

        <Button type="submit" class="w-full">
          submit
        </Button>
      </div>
    </form>
  </div>
</template>
