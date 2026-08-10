import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

// cn() merges Tailwind class strings, with later classes overriding earlier ones
// (so e.g. cn("text-sm", condition && "text-lg") picks the larger size when the
// condition is true). Use everywhere a className is computed conditionally.
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
