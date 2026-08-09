import { LoginForm } from "@/components/login-form";

export default function LoginPage() {
  return (
    <div className="flex flex-col gap-6">
      <div className="flex flex-col gap-1">
        <h1 className="text-2xl font-semibold tracking-tight text-zinc-900 dark:text-zinc-50">
          Welcome to Kartik OS
        </h1>
        <p className="text-sm text-zinc-600 dark:text-zinc-400">
          Sign in with your email to receive a one-time link.
        </p>
      </div>
      <LoginForm />
    </div>
  );
}
