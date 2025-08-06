import { Welcome } from "@kombination/ui-components/Welcome.tsx";
import { Header } from "./shared/components/Header";

function App() {
	return (
		<div className="p-0 xs:py-4">
			<Header />
			<Welcome />
		</div>
	);
}

export default App;
