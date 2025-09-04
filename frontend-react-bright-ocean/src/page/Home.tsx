import { useAuth0 } from '@auth0/auth0-react';
import AppLayout from '../component/app/AppLayout';
import { APP_CONFIG } from '../config';

const Home = () => {
  const { user } = useAuth0();
  return (
    <AppLayout title={`Welcome to ${APP_CONFIG.app.name}${user?.name ? (', ' + user.name) : ''}`} authRequired={false}>
      <div>
        <h3 className="text-lg font-medium text-gray-800">{APP_CONFIG.app.name} is awesome</h3>
      </div>
    </AppLayout>
  );
};

export default Home;