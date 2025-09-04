import { Redirect, Route, Router, Switch } from 'wouter'
import './App.css'
import Auth0Callback from './component/app/Auth0Callback'
import About from './page/About'
import AdminHome from './page/AdminHome'
import Api from './page/Api'
import Help from './page/Help'
import Home from './page/Home'
import NotFound from './page/NotFound'
import Notifications from './page/Notifications'
import Price from './page/Price'
import Privacy from './page/Privacy'
import Profile from './page/Profile'
import Settings from './page/Settings'
import Terms from './page/Terms'

function App() {
  return (
    <Router>
      <Switch>
        <Route path="/" component={() => <Redirect to="/home" />} />
        <Route path="/home" component={Home} />
        <Route path="/about" component={About} />
        <Route path="/help" component={Help} />
        <Route path="/terms" component={Terms} />
        <Route path="/privacy" component={Privacy} />
        <Route path="/auth0/:operation" component={Auth0Callback} />

        <Route path="/profile" component={Profile} />
        <Route path="/settings" component={Settings} />
        <Route path="/api" component={Api} />
        <Route path="/price" component={Price} />
        <Route path="/notifications" component={Notifications} />

        <Route path="/admin">
          <Route path="/" component={AdminHome} />
        </Route>

        <Route path="/*" component={NotFound} />
      </Switch>
    </Router>
  )
}

export default App