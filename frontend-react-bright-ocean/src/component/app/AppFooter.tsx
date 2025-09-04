import { useAuth0 } from '@auth0/auth0-react';
import { BadgeInfo, BadgeQuestionMark, Rss } from 'lucide-react';
import { APP_CONFIG } from '../../config';

const AppFooter = () => {
  const currentYear = new Date().getFullYear();
  const { isAuthenticated } = useAuth0();
  return (
    <footer className="bg-dark-green text-white border-t border-gray-700">
      <div className="container mx-auto px-4 py-6">
        <div className="flex flex-col md:flex-row justify-between items-center space-y-4 md:space-y-0">
          <div className="flex items-center space-x-4">
            <span className="text-gray-500 text-sm">
              {APP_CONFIG.environment}{APP_CONFIG.hash ? ('@' + APP_CONFIG.hash.substring(0, 7)) : ''}
            </span>
          </div>

          <div className="flex items-center space-x-6 text-sm gap-x-16">
            <a href="/help" className="text-gray-300 hover:text-white transition-colors">
              <div className='flex items-center gap-x-1'>
                <BadgeQuestionMark /> Help
              </div>
            </a>
            <a href="/about" className="text-gray-300 hover:text-white transition-colors">
              <div className='flex items-center gap-x-1'>
                <BadgeInfo /> About
              </div>
            </a>
            {isAuthenticated && <a href="/api" className="text-gray-300 hover:text-white transition-colors">
              <div className='flex items-center gap-x-1'>
                <Rss /> Api
              </div>
            </a>}
          </div>

          <div className="text-gray-400 text-sm font-semibold text-yellow-green">
            © {currentYear} {APP_CONFIG.name}
          </div>
        </div>
      </div>
    </footer>
  );
};

export default AppFooter;