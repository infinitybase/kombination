import { useEffect, useState } from 'react'

function formatTime(ms: number): string {
  if (ms <= 0) return '00:00:00'

  const totalSeconds = Math.floor(ms / 1000)
  const hours = String(Math.floor(totalSeconds / 3600)).padStart(2, '0')
  const minutes = String(Math.floor((totalSeconds % 3600) / 60)).padStart(2, '0')
  const seconds = String(totalSeconds % 60).padStart(2, '0')

  return `${hours}:${minutes}:${seconds}`
}

export function useCountdown(inputDate: Date | string) {
  const [timeLeft, setTimeLeft] = useState('00:00:00')

  useEffect(() => {
    const date = typeof inputDate === 'string' ? new Date(inputDate) : inputDate
    if (isNaN(date.getTime())) {
      setTimeLeft('Invalid date')
      return
    }

    const endOfDay = new Date(date)
    endOfDay.setHours(23, 59, 59, 999)

    const updateCountdown = () => {
      const now = new Date()
      const diff = endOfDay.getTime() - now.getTime()
      setTimeLeft(formatTime(diff))
    }

    updateCountdown()
    const interval = setInterval(updateCountdown, 1000)

    return () => clearInterval(interval)
  }, [inputDate])

  return timeLeft
}
