// Auth routes share a centered, minimal layout. The dashboard and other
// authenticated routes use a different layout (Phase 2+).

export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex min-h-full flex-1 items-center justify-center px-6 py-12">
      <div className="w-full max-w-sm">{children}</div>
    </div>
  );
}
