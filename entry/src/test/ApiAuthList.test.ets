import apiContractTest from './ApiContract.test';
import authStateMachineTest from './AuthStateMachine.test';
import playbackContractTest from './PlaybackContract.test';

export default function apiAuthTests(): void {
  apiContractTest();
  authStateMachineTest();
  playbackContractTest();
}
