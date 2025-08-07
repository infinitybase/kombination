import { MainLayout } from "@/components/layout/MainLayout"; 
import { AutoParts } from "@/features/auto-parts/screens/AutoParts";
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/autoparts")({
  component: RouteComponent,
});

function RouteComponent() {
  return (
    <MainLayout>
      <AutoParts />
    </MainLayout>
  );
}