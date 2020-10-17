use raft::Simulator;

fn main() {
    let mut simulator = Simulator::new(5);
    simulator.run();
}
