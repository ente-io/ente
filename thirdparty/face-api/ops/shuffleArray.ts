export function shuffleArray(inputArray: any[]) {
  const array = inputArray.slice()
  for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const x = array[i]
      array[i] = array[j]
      array[j] = x
  }
  return array
}