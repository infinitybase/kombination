import { MainLayout } from "@/components/layout/MainLayout"; 
import {
  Outlet,
  createFileRoute
} from "@tanstack/react-router";

export const Route = createFileRoute("/garage")({
  component: RouteComponent,
});

function RouteComponent() {
  return (
    <MainLayout>
      <Outlet />
    </MainLayout>
  );
}