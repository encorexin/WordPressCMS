/**
 * 扩展环境错误边界
 * 捕获并显示扩展中的错误
 */

import { Component, type ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
  errorInfo: string;
}

export class ExtensionErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: '' };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, errorInfo: '' };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('扩展错误:', error);
    console.error('错误详情:', errorInfo);
    this.setState({ errorInfo: errorInfo.componentStack });
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          padding: '20px',
          fontFamily: 'system-ui, -apple-system, sans-serif',
          color: '#333'
        }}>
          <h2 style={{ color: '#dc2626', marginBottom: '16px' }}>
            ⚠️ 扩展加载出错
          </h2>
          <div style={{
            background: '#fef2f2',
            border: '1px solid #fecaca',
            borderRadius: '8px',
            padding: '16px',
            marginBottom: '16px'
          }}>
            <p style={{ fontWeight: 'bold', marginBottom: '8px' }}>
              错误信息:
            </p>
            <pre style={{
              background: '#fff',
              padding: '12px',
              borderRadius: '4px',
              overflow: 'auto',
              fontSize: '12px',
              margin: 0
            }}>
              {this.state.error?.toString()}
            </pre>
          </div>
          {this.state.errorInfo && (
            <div style={{
              background: '#f3f4f6',
              border: '1px solid #e5e7eb',
              borderRadius: '8px',
              padding: '16px'
            }}>
              <p style={{ fontWeight: 'bold', marginBottom: '8px' }}>
                组件堆栈:
              </p>
              <pre style={{
                fontSize: '11px',
                overflow: 'auto',
                margin: 0,
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-all'
              }}>
                {this.state.errorInfo}
              </pre>
            </div>
          )}
          <button
            onClick={() => window.location.reload()}
            style={{
              marginTop: '16px',
              padding: '8px 16px',
              background: '#667eea',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: 'pointer'
            }}
          >
            重新加载
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
