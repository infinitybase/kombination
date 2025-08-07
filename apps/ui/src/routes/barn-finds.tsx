import { MainLayout } from "@/components/layout/MainLayout"; 
import { BarnFinds } from "@/features/barn-finds/screens/BarnFinds";
import {
  createFileRoute
} from "@tanstack/react-router";

export const Route = createFileRoute("/barn-finds")({
  component: RouteComponent,
});

function RouteComponent() {
  return (
    <MainLayout>
      <BarnFinds />
    </MainLayout>
  );
}