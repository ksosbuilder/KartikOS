// Small utility barrel. Add shadcn's cn() helper here in the shadcn step.

export function cn(...classes: Array<string | undefined | null | false>): string {
  return classes.filter(Boolean).join(" ");
}
