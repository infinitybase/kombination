import { Header } from "./components/Header";
import { BarnFinds } from "./features/barn-finds/screens/BarnFinds";

function App() {
	return (
		<div className="p-0 xs:py-4 h-page-height">
			<Header />
			<BarnFinds />
		</div>
	);
}

export default App;
