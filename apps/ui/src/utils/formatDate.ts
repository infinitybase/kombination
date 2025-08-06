export function formatDate(input: string | Date): string {
  const date = new Date(input)

  if (isNaN(date.getTime())) return 'Invalid date'

  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
}