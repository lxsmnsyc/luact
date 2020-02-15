import React from 'react';

function App() {
  const user = React.useRef('');
  const password = React.useRef('');

  const onUserChange = React.useCallback((e) => {
    user.current = e.currentTarget.value;
  }, []);
  const onPasswordChange = React.useCallback((e) => {
    password.current = e.currentTarget.value;
  }, []);
  const login = React.useCallback(() => {
    alert(user.current);
    alert(password.current);
  }, []);

  return (
    <div>
      Username <input type="text" onChange={onUserChange} />
      Password <input type="password" onChange={onPasswordChange} />
      <button onClick={login}>Click me</button>
    </div>
  )
}

