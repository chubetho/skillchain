<script setup lang="ts">
const store = useStore()
const committeeFactory = await store.getCommitteeFactory()
console.log(await committeeFactory.getReviewRequestDetails(0))
console.log(await committeeFactory.getCommitteeVotes(0))
console.log(await committeeFactory.getCommitteeMemberArray(0))
console.log(await committeeFactory.getAvailableCommitteeMemberCount())
</script>

<template>
  <div class="py-10">
    committee
  </div>
</template>
